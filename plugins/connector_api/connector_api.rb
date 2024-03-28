# frozen_string_literal: true

require_relative '../../lib/config'
require_relative '../../lib/keys'
require_relative '../../lib/user'
require_relative '../../lib/client'

require 'base64'
require 'tmpdir'

after '/api/v1/connectors/*' do
  headers['Content-Type'] = 'application/json'
end

before '/api/v1/connectors/*' do
  return if request.env['REQUEST_METHOD'] == 'OPTIONS'
rescue StandardError => e
  p e if debug
  halt 401
end

endpoint '/api/v1/connectors/add', ['GET'], public_endpoint: true do
  # json = JSON.parse request.body.read
  
  client_name = "plugintest"
  keystore_password = "123456"

  gen_cert_cmd = "./scripts/register_connector.sh #{client_name} 2>&1"
  gen_cert_cmd_value = `#{gen_cert_cmd}`

  cert_to_pem_cmd_value = ""
  export_keystore_cmd_value = ""
  encoded = ""
  Dir.mktmpdir do |d|
    cert_to_pem_cmd = "openssl x509 -in keys/#{client_name}.cert -out #{d}/#{client_name}.cert.pem -outform PEM 2>&1"
    cert_to_pem_cmd_value = `#{cert_to_pem_cmd}`
    export_keystore_cmd = "openssl pkcs12 --password pass:#{keystore_password} -export -in #{d}/#{client_name}.cert.pem -inkey keys/#{client_name}.key -out #{d}/#{client_name}.cert.pfx 2>&1"
    export_keystore_cmd_value = `#{export_keystore_cmd}`

    data = File.open("#{d}/#{client_name}.cert.pfx").read
    encoded = Base64.encode64(data)
  end

  halt 200, JSON.generate({"result": gen_cert_cmd_value + cert_to_pem_cmd_value + export_keystore_cmd_value, "keystore": encoded, "password": keystore_password})
end