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
  if ARGV[2].start_with? '!'
    is_refresh = true
    ARGV[2] = ARGV[2].gsub(/!/, '')
  end

  # contants
  BASECRM_API_KEY = "#{ARGV[0]}"

  @session = BaseCrm::Session.new(BASECRM_API_KEY)
  @filter = ARGV[1]
  @query = ARGV[2]
  @parts = ARGV[2].split(" ")
  @fb = alfred.feedback

  def load_leads()

    leads = []
    page = []
    page_no = 1

    begin
      page = @session.leads.all(page: page_no)
      leads << page
      page_no += 1
    end until page.size < 50

    leads.flatten!

    leads.each do |lead|
      lead_name = [lead.first_name, lead.last_name].join(" ")
      lead_url = "https://app.futuresimple.com/leads/#{lead.id}"

      @fb.add_item({
        :uid => "lead-#{lead.id}",
        :title => lead_name,
        :subtitle => 'Lead',
        :arg => lead_url,
        :autocomplete => lead_name,
        :icon => { :type => "default", :name => "assets/lead.png" },
        :valid => "yes"
      })
    end

  end

  def load_contacts()

    contacts = []
    page = []
    page_no = 1

    begin
      page = @session.contacts.all(page: page_no)
      contacts << page
      page_no += 1
    end until page.size < 20

    contacts.flatten!

    contacts.each do |contact|
      contact_url = "https://app.futuresimple.com/crm/contacts/#{contact.id}"

      @fb.add_item({
        :uid => "contact-#{contact.id}",
        :title => contact.name,
        :subtitle => contact.is_organisation ? 'Account' : 'Contact',
        :arg => contact_url,
        :autocomplete => contact.name,
        :icon => { :type => "default", :name => contact.is_organisation ? 'assets/organisation.png' : "assets/contact.png" },
        :valid => "yes"
      })
    end

  end

  def load_deals()

    deals = []
    page = []
    page_no = 1

    begin
      page = @session.deals.all(page: page_no)
      deals << page
      page_no += 1
    end until page.size < 20

    deals.flatten!

    deals.each do |deal|
      deal_url = "https://app.futuresimple.com/sales/deals/#{deal.id}"

      @fb.add_item({
        :uid => "deal-#{deal.id}",
        :title => deal.name,
        :subtitle => 'Deal',
        :arg => deal_url,
        :autocomplete => deal.name,
        :icon => { :type => "default", :name => "assets/deal.png" },
        :valid => "yes"
      })
    end
  end

  alfred.with_rescue_feedback = true
  alfred.with_cached_feedback do
    use_cache_file :expire => 86400
  end

  @fb = alfred.feedback.get_cached_feedback

  if is_refresh or @fb.nil?

    load_leads()
    load_contacts()
    load_deals()

    @fb.put_cached_feedback

  end


  puts @fb.to_alfred(@query)


end



