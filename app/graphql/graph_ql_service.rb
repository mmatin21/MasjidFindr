# app/services/graph_ql_service.rb
require 'net/http'
require 'uri'
require 'json'

class GraphQlService
  if Rails.env.development?
    BASE_URL = 'http://localhost:3001/graphql'
  else
    BASE_URL = 'https://mosqueapp-test.onrender.com/graphql'
  end
  
  class << self
    private

    def execute_query(query)
      uri = URI(BASE_URL)
      headers = {
        "Content-Type" => "application/json",
        "X-Api-Key" => Rails.application.credentials.dig(:masjidmanager, :api_key)
      }

      response = Net::HTTP.post(uri, { query: query }.to_json, headers)
      JSON.parse(response.body)
    end
  end

  def self.fetch_masjids
    query = <<~GRAPHQL
      {
        masjids {
          id
          name
          address
          city
          state
          zipcode
          latitude
          longitude
        }
      }
    GRAPHQL

    execute_query(query)
  end

  def self.fetch_masjid_by_id(masjid_id)
    query = <<~GRAPHQL
      {
        masjidById(id: #{masjid_id.to_i}) {
          stripeAccountId
          name
          address
          city
          state
          zipcode
          fundraisers {
            id
            name
            goalAmount
            description
            endDate
          }
          events {
            id
            name
            description
            formattedEventDate
            address
          }
          prayers {
            id
            name
            adhaan
            iqaamah
            formattedAdhaan
            formattedIqaamah
          }
        }
      }
    GRAPHQL

    execute_query(query)
  end

  def self.fetch_fundraisers_by_id(id)
    query = <<~GRAPHQL
      {
        fundraiserById(id: #{id.to_i}) {
          id
          name
          goalAmount
          description
          endDate
          masjidId
        }
      }
    GRAPHQL

    execute_query(query)
  end
end
