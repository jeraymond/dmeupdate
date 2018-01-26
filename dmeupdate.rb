###############################################################################
# Copyright 2014 Jeremy Raymond
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

require 'logger'
require 'net/http'
require 'yaml'

# EXT_IP_URL = 'http://www.dnsmadeeasy.com/myip.jsp'
# myexternalip seems to be more reliable than dnsmadeeasy myip
EXT_IP_URL = 'https://myexternalip.com/raw'
UPDATE_URL = 'https://cp.dnsmadeeasy.com/servlet/updateip'

begin
  script_dir = File.join(File.dirname(File.expand_path(__FILE__)))

  $log = Logger.new("#{script_dir}/dmeupdate.log", 'weekly')
  $log.formatter = proc do |severity, datetime, progname, msg|
    formatted_date = datetime.strftime("%Y-%m-%dT%H:%M:%S %Z")
    "#{formatted_date} - #{severity}: #{msg}\n"
  end

  config = YAML::load_file(File.join(script_dir, 'dmeupdate.yaml'))
  exit_code = 0
  $log.info "Starting record updates"
  config[:records].each do |record|
    username = record[:username]
    password = record[:password]
    record_id = record[:record_id]
    $log.info "Updating record #{record_id}"
    
    ip_response = Net::HTTP.get_response(URI(EXT_IP_URL))
    if ip_response.is_a? Net::HTTPOK
      ip_address = ip_response.body
      ip_address.strip!
      $log.info "Found external ip_address='#{ip_address}'"
    else
      $log.error "Failed to get external IP address"
      $log.error ip_response.body
      exit_code = 1
      next
    end
    
    uri = URI("#{UPDATE_URL}?username=#{username}&password=#{password}" \
              "&id=#{record_id}&ip=#{ip_address}")

    # To fix SSL verification problems
    # ruby -ropenssl -e "p OpenSSL::X509::DEFAULT_CERT_FILE"
    # wget -O /etc/ssl/cert.pem http://curl.haxx.se/ca/cacert.pem
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      request = Net::HTTP::Get.new uri.request_uri
      response = http.request request
      if response.is_a? Net::HTTPOK and "success".eql? response.body
        $log.info "Successfully updated record_id=#{record_id} ip_address='#{ip_address}' " \
                  "http_response_body=#{response.body}"
      else
        $log.error "Update request failed for record_id=#{record_id} ip_address='#{ip_address}' " \
                   "HTTP #{response.code} #{response.body}"
        exit_code = 1
      end
    end
  end
  exit exit_code
rescue RuntimeError => e
  $log.error(e)
  exit 1
end
