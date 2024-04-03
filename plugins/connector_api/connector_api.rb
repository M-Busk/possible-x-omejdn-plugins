# frozen_string_literal: true

require_relative '../../lib/config'
require_relative '../../lib/keys'
require_relative '../../lib/user'
require_relative '../../lib/client'

require 'base64'
require 'tmpdir'
require 'securerandom'

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
  client_name = SecureRandom.uuid
  keystore_password = SecureRandom.base64(24)

  if File.exists?("keys/#{client_name}.cert")
    halt 409
  end

  gen_cert_cmd = "./scripts/register_connector.sh #{client_name}"
  gen_cert_cmd_value = `#{gen_cert_cmd}`
  client_id = gen_cert_cmd_value.strip

  keystore_encoded = ""
  Dir.mktmpdir do |d|
    cert_to_pem_cmd = "openssl x509 -in keys/#{client_name}.cert -out #{d}/#{client_name}.cert.pem -outform PEM 2>&1"
    `#{cert_to_pem_cmd}`
    export_keystore_cmd = "openssl pkcs12 --password pass:#{keystore_password} -export -in #{d}/#{client_name}.cert.pem -inkey keys/#{client_name}.key -out #{d}/#{client_name}.cert.pfx 2>&1"
    `#{export_keystore_cmd}`

    keystore_file = File.open("#{d}/#{client_name}.cert.pfx", "rb")
    keystore_data = keystore_file.read
    keystore_file.close
    keystore_encoded = Base64.strict_encode64(keystore_data)
  end

  halt 200, JSON.generate({
    "client_name": client_name,
    "client_id": client_id,
    "keystore": keystore_encoded, 
    "password": keystore_password
  })
end