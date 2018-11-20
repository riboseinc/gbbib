# frozen_string_literal: true

require 'gbbib/gb_bibliographic_item'
require 'gbbib/workers_pool'

# GB bib module.
module Gbbib
  # GB entry point class.
  class GbBibliography
    class << self
      # rubocop:disable Metrics/MethodLength
      # @param text [Strin] code of standard for search
      # @return [Gbbib::HitCollection]
      def search(text)
        if text =~ /^(GB|GJ|GS)/
          # Scrape national standards.
          require 'gbbib/gb_scrapper'
          GbScrapper.scrape_page text
        elsif text =~ /^ZB/
          # Scrape proffesional.
        elsif text =~ /^DB/
          # Scrape local standard.
        elsif text =~ %r{^Q\/}
          # Enterprise standard
        elsif text =~ %r{^T\/[^\s]{3,6}\s}
          # Scrape social standard.
          require 'gbbib/t_scrapper'
          TScrapper.scrape_page text
        else
          # Scrape sector standard.
          require 'gbbib/sec_scrapper'
          SecScrapper.scrape_page text
        end
      end
      # rubocop:enable Metrics/MethodLength

      # @param code [String] the GB standard Code to look up (e..g "GB/T 20223")
      # @param year [String] the year the standard was published (optional)
      # @param opts [Hash] options; restricted to :all_parts if all-parts reference is required
      # @return [String] Relaton XML serialisation of reference
      def get(code, year, opts)
        code += '.1' if opts[:all_parts]
        ret = get1(code, year, opts)
        return nil if ret.nil?
        ret.to_most_recent_reference unless year
        ret.to_all_parts if opts[:all_parts]
        ret
      end

      private

      def fetch_ref_err(code, year, missed_years)
        id = year ? "#{code}:#{year}" : code
        warn "WARNING: no match found on the GB website for #{id}. "\
          "The code must be exactly like it is on the website."
        warn "(There was no match for #{year}, though there were matches "\
          "found for #{missed_years.join(', ')}.)" unless missed_years.empty?
        if /\d-\d/ =~ code
          warn "The provided document part may not exist, or the document "\
            "may no longer be published in parts."
        else
          warn "If you wanted to cite all document parts for the reference, "\
            "use \"#{code} (all parts)\".\nIf the document is not a standard, "\
            "use its document type abbreviation (TS, TR, PAS, Guide)."
        end
        nil
      end

      def get1(code, year, opts)
        result = search_filter(code) or return nil
        ret = results_filter(result, year)
        return ret[:ret] if ret[:ret]
        fetch_ref_err(code, year, ret[:years])
      end

      def search_filter(code)
        docidrx = %r{^[^\s]+\s[\d\.]+}
        # corrigrx = %r{^[^\s]+\s[\d\.]+-[0-9]+/}
        warn "fetching #{code}..."
        result = search(code)
        ret = result.select do |hit|
          hit.title && hit.title.match(docidrx).to_s == code # &&
            # !corrigrx =~ hit.title
        end
        return ret unless ret.empty?
        []
      end

      # Sort through the results from Isobib, fetching them three at a time,
      # and return the first result that matches the code,
      # matches the year (if provided), and which # has a title (amendments do not).
      # Only expects the first page of results to be populated.
      # Does not match corrigenda etc (e.g. ISO 3166-1:2006/Cor 1:2007)
      # If no match, returns any years which caused mismatch, for error reporting
      def results_filter(result, year)
        missed_years = []
        result.each_slice(3) do |s| # ISO website only allows 3 connections
          fetch_pages(s, 3).each_with_index do |r, i|
            return { ret: r } if !year
            r.dates.select { |d| d.type == "published" }.each do |d|
              return { ret: r } if year.to_i == d.on.year
              missed_years << d.on.year
            end
          end
        end
        { years: missed_years }
      end

      def fetch_pages(s, n)
        workers = WorkersPool.new n
        workers.worker { |w| { i: w[:i], hit: w[:hit].fetch } }
        s.each_with_index { |hit, i| workers << { i: i, hit: hit } }
        workers.end
        workers.result.sort { |x, y| x[:i] <=> y[:i] }.map { |x| x[:hit] }
      end
    end
  end
end
