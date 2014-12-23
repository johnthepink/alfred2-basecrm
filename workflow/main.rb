#!/usr/bin/env ruby
# encoding: utf-8

($LOAD_PATH << File.expand_path("..", __FILE__)).uniq!

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require "bundle/bundler/setup"
require "alfred"
require "httparty"

Alfred.with_friendly_error do |alfred|

  # prepend ! in query to refresh
  is_refresh = false
  if ARGV[1].start_with? '!'
    is_refresh = true
    ARGV[1] = ARGV[1].gsub(/!/, '')
  end

  # contants
  BASECRM_API_KEY = "#{ARGV[0]}"
  QUERY = ARGV[1]
  URL = 'https://sync.futuresimple.com/api/v1/search.json'
  UUID = '00AA0000-000A-000A-0000-AAA00A0AAAAA'

  @fb = alfred.feedback

  def load_data()
    results = HTTParty.get(URL,
      headers: {
        'X-Basecrm-Device-UUID' => UUID,
        'X-Futuresimple-Token' => BASECRM_API_KEY
      }
    )

    results.each do |result|
      case result["metadata"]["data_type"]
      when "Deal"
        add_deal(result)
      when "Lead"
        add_lead(result)
      when "Contact"
        if is_company?(result)
          add_company(result)
        else
          add_contact(result)
        end
      end
    end
  end

  def add_basecrm_item(uid, title, type, url)
    @fb.add_item({
      :uid => uid,
      :title => title,
      :subtitle => type.capitalize,
      :arg => url,
      :autocomplete => title,
      :icon => { :type => "default", :name => "assets/#{type}.png" },
      :valid => "yes"
    })
  end

  def add_deal(result)
    uid = "#{result["metadata"]["data_type"]}-#{result["data"]["id"]}"
    title = result["data"]["name"]
    url = "https://app.futuresimple.com/sales/deals/#{result["data"]["id"]}"

    add_basecrm_item(uid, title, "deal", url)
  end

  def add_lead(result)
    uid = "#{result["metadata"]["data_type"]}-#{result["data"]["id"]}"
    if result["data"]["first_name"].nil?
      title = result["data"]["company_name"]
    else
      title = "#{result["data"]["first_name"]} #{result["data"]["last_name"]}"
    end
    url = "https://app.futuresimple.com/leads/#{result["data"]["id"]}"

    add_basecrm_item(uid, title, "lead", url)
  end

  def add_contact(result)
    uid = "#{result["metadata"]["data_type"]}-#{result["data"]["id"]}"
    title = "#{result["data"]["first_name"]} #{result["data"]["last_name"]}"
    url = "https://app.futuresimple.com/crm/contacts/#{result["data"]["id"]}"

    add_basecrm_item(uid, title, "contact", url)
  end

  def add_company(result)
    uid = "#{result["metadata"]["data_type"]}-#{result["data"]["id"]}"
    title = result["data"]["name"]
    url = "https://app.futuresimple.com/crm/contacts/#{result["data"]["id"]}"

    add_basecrm_item(uid, title, "company", url)
  end

  def is_company?(result)
    result["data"]["first_name"].nil?
  end

  alfred.with_rescue_feedback = true
  # alfred.with_cached_feedback do
  #   use_cache_file :expire => 86400
  # end

  load_data()
  puts @fb.to_alfred(QUERY)

  # if !is_refresh and fb = alfred.feedback.get_cached_feedback
  #   # cached feedback is valid
  #   puts fb.to_alfred(QUERY)
  # else
  #   fb = load_data(alfred)
  #   fb.put_cached_feedback
  #   puts fb.to_alfred(QUERY)
  # end
end



