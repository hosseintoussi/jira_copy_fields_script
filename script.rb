require 'net/https'
require 'JSON'
require 'yaml'

config = YAML.load_file('config.yml')

project_url = "https://mindvalley.atlassian.net/rest/api/2/search?jql=project='#{config['project']}'&maxResults=#{config['max_results']}"
uri = URI(project_url.strip)
all_issues = ""
# puts "============magic==========="
# puts project_url
# puts config['project']
# puts config['username']
# puts config['password']
# puts config['old_custom_field']
# puts config['new_custom_field']
# puts "======================="


Net::HTTP.start(uri.host, uri.port,
                :use_ssl => uri.scheme == 'https',
:verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

  request = Net::HTTP::Get.new uri.request_uri
  request.basic_auth "#{config['username']}", "#{config['password']}"

  response = http.request request # Net::HTTPResponse object

  all_issues = JSON.parse(response.body)
end

puts "Total issues: #{all_issues["total"]}"

all_issues["issues"].each do |issue|
  puts "======================="
  if !issue["fields"]["#{config['old_custom_field']}"].nil?
    old_field_value = issue["fields"]["#{config['old_custom_field']}"]
    new_field = config['new_custom_field']
    url = "https://mindvalley.atlassian.net/rest/api/2/issue/#{issue["key"]}"
    uri1 = URI(url.strip)
    puts "#{config['old_custom_field']} of #{issue["key"]} has the value of: #{old_field_value}"

    req = Net::HTTP::Put.new uri1.request_uri
    req.basic_auth "#{config['username']}", "#{config['password']}"
    req['Content-Type'] = 'application/json'
    req.body = "{\"fields\":{\"#{new_field}\":\"#{old_field_value}\"}}"
    Net::HTTP.start(uri1.host, uri1.port,
                    :use_ssl => uri.scheme == 'https',
    :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      response = http.request req
      puts response
    end
  else
    puts "Skipping for #{issue["key"]} as there is no field of #{config['old_custom_field']}."
  end
  puts "======================="
end
