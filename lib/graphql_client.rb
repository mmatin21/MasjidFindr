require 'graphql'
require 'net/http'
require 'uri'
require 'json'

# Set the URI for the GraphQL endpoint
uri = URI('https://mosqueapp-test.onrender.com/graphql')

# Define the GraphQL query you want to execute
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

# Parse the JSON response
result = JSON.parse(response.body)

# Output the result to the console
puts JSON.pretty_generate(result)
