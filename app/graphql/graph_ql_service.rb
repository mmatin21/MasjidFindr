# app/services/graph_ql_service.rb
require 'net/http'
require 'uri'
require 'json'

class GraphQlService
  def self.fetch_masjids
    # Set the URI for the GraphQL endpoint
    uri = URI('https://mosqueapp-test.onrender.com/graphql')

    # Define the GraphQL query
    query = {
      query: <<~GRAPHQL
        {
          masjids {
            name
            address
            city
            state
            zipcode
          }
        }
      GRAPHQL
    }

    # Make the POST request to the GraphQL endpoint
    response = Net::HTTP.post(uri, query.to_json, "Content-Type" => "application/json")

    # Parse and return the JSON response
    JSON.parse(response.body)
  end
end
