#!/usr/bin/env ruby
# encoding: utf-8

($LOAD_PATH << File.expand_path("..", __FILE__)).uniq!

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require "bundle/bundler/setup"
require "alfred"
require "basecrm"

Alfred.with_friendly_error do |alfred|

  # prepend ! in query to refresh
  is_refresh = false
  if ARGV[0].start_with? '!'
    is_refresh = true
    ARGV[0] = ARGV[0].gsub(/!/, '')
  end

  # contants
  QUERY = ARGV[0]
  BASECRM_API_KEY = "#{ARGV[1]}"

  def load_leads(alfred)

    session = BaseCrm::Session.new(BASECRM_API_KEY)
    fb = alfred.feedback

    session.leads.all.each do |lead|
      lead_name = [lead.first_name, lead.last_name].join(" ")
      lead_url = "https://app.futuresimple.com/leads/#{lead.id}"

      fb.add_item({
        :uid => "lead-#{lead.id}",
        :title => lead_name,
        :subtitle => 'Lead',
        :arg => lead_url,
        :autocomplete => lead_name,
        :valid => "yes"
      })
    end

    session.contacts.all.each do |contact|
      contact_url = "https://app.futuresimple.com/crm/contacts/#{contact.id}"

      fb.add_item({
        :uid => "contact-#{contact.id}",
        :title => contact.name,
        :subtitle => 'Contact',
        :arg => contact_url,
        :autocomplete => contact.name,
        :valid => "yes"
      })
    end

    session.deals.all.each do |deal|
      deal_url = "https://app.futuresimple.com/sales/deals/#{deal.id}"

      fb.add_item({
        :uid => "deal-#{deal.id}",
        :title => deal.name,
        :subtitle => 'Deal',
        :arg => deal_url,
        :autocomplete => deal.name,
        :valid => "yes"
      })
    end

    fb
  end

  alfred.with_rescue_feedback = true
  alfred.with_cached_feedback do
    use_cache_file :expire => 86400
  end

  if !is_refresh and fb = alfred.feedback.get_cached_feedback
    # cached feedback is valid
    puts fb.to_alfred(ARGV[0])
  else
    fb = load_leads(alfred)
    fb.put_cached_feedback
    puts fb.to_alfred(ARGV[0])
  end
end



