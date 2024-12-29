# app/services/graph_ql_service.rb
require 'net/http'
require 'uri'
require 'json'

class GraphQlService
  def self.fetch_masjids
    # Set the URI for the GraphQL endpoint
    uri = URI('http://localhost:3001/graphql')

    # Define the GraphQL query
    query = {
      query: <<~GRAPHQL
        {
          masjids {
            id
            name
            address
            city
            state
            zipcode
          }
        }
      GRAPHQL
    }

    api_key = Rails.application.credentials.dig(:masjidmanager, :api_key)

    # Define the headers including the API key for authorization
    headers = {
      "Content-Type" => "application/json",
      "X-Api-Key" => "#{api_key}"
    }

    # Make the POST request to the GraphQL endpoint
    response = Net::HTTP.post(uri, query.to_json, headers)

    # Parse and return the JSON response
    JSON.parse(response.body)
  end

  def self.fetch_fundraisers_for_masjid(masjid_id)
    uri = URI('http://localhost:3001/graphql')

    query = {
      query: <<~GRAPHQL
        {
          fundraisers(masjidId: #{masjid_id}) {
            id
            name
            goalAmount
            description
            createdAt
          }
        }
      GRAPHQL
    }

    response = Net::HTTP.post(uri, query.to_json, "Content-Type" => "application/json")
    JSON.parse(response.body)
  end

  def self.fetch_masjid_by_id(masjid_id)
    uri = URI('http://localhost:3001/graphql')

    query = {
      query: <<~GRAPHQL
        {
          masjidById(id: #{masjid_id}) {
            stripeAccountId
          }
        }
      GRAPHQL
    }

    response = Net::HTTP.post(uri, query.to_json, "Content-Type" => "application/json")
    JSON.parse(response.body)
  end

  def self.fetch_fundraisers_by_id(id)
    uri = URI('http://localhost:3001/graphql')

    query = {
      query: <<~GRAPHQL
        {
          fundraiserById(id: #{id}) {
            id
            name
            goalAmount
            description
            endDate
            masjidId
          }
        }
      GRAPHQL
    }

    response = Net::HTTP.post(uri, query.to_json, "Content-Type" => "application/json")
    JSON.parse(response.body)
  end

  def self.create_donation(fundraiser_id, amount, contact_email, contact_first_name, contact_last_name, contact_phone_number)
    uri = URI('http://localhost:3001/graphql')
    query = {
      query: <<~GRAPHQL
        mutation {
          createDonation(input: {
            fundraiserId: #{fundraiser_id},
            amount: #{amount},
            contactEmail: "#{contact_email}",
            contactFirstName: "#{contact_first_name}",
            contactLastName: "#{contact_last_name}",
            contactPhoneNumber: "#{contact_phone_number}"
          }) {
            donation {
              fundraiserId
              amount
              contact {
                id
                email
                firstName
                lastName
                phoneNumber
              }
            }
          }
        }
      GRAPHQL
    }
    response = Net::HTTP.post(uri, query.to_json, "Content-Type" => "application/json")
    JSON.parse(response.body)
  end


end
