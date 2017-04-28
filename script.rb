require "net/https"
require "JSON"
require "yaml"

class Config
  attr_reader :base_url,
    :project,
    :max_results,
    :username,
    :password,
    :old_custom_field,
    :new_custom_field

  def initialize(file = YAML.load_file("config.yml"))
    @base_url = file["base_url"]
    @project = file["project"]
    @max_results = file["max_results"]
    @username = file["username"]
    @password = file["password"]
    @old_custome_field = file["old_custom_field"]
    @new_custome_field = file["new_custom_field"]
  end

  def project_uri
    URI("#{base_url}/rest/api/2/search?jql=project='#{project}'&maxResults=#{max_results}".strip)
  end
end

class JiraCopyFields
  attr_reader :config

  def initialize(config = Config.new)
    @config = config
  end

  def run
    all_issues["issues"].each do |issue|
      puts "======================="
      next unless issue["fields"][config.old_custom_field]
      update_issue(issue)
    end
  end

  private

  def update_issue(issue)
    old_field_value = issue["fields"][config.old_custom_field]
    new_field = config.new_custome_field

    req = Net::HTTP::Put.new post_uri.request_uri
    req.basic_auth(config.username, config.password)
    req["Content-Type"] = "application/json"
    req.body = "{\"fields\":{\"#{new_field}\":\"#{old_field_value}\"}}"
    Net::HTTP.start(post_uri(issue["key"]).host, post_uri(issue["key"]).port, :use_ssl => config.project_uri.scheme == "https", :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      puts http.request(req)
    end
  end

  def post_uri(key)
    URI("#{base_url}/rest/api/2/issue/#{key}".strip)
  end

  def all_issues
    @_all_issues ||= Net::HTTP.start(config.project_uri.host, config.project_uri.port, :use_ssl => config.project_uri.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Get.new config.project_uri.request_uri
      request.basic_auth(config.username, config.password)
      response = http.request request # Net::HTTPResponse object
      JSON.parse(response.body)
    end
  end
end


## Runs here
JiraCopyFields.new.run

