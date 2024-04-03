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
  json = JSON.parse request.body.read

  # use client name of body if available
  if @json['client_name']
    client_name = json['client_name']
  else
    client_name = SecureRandom.uuid
  end

  # generate a new password for the keystore
  keystore_password = SecureRandom.base64(24)

  client_id = ""
  if File.exists?("keys/#{client_name}.cert") # if cert already exists, read the client id
    get_ski_cmd = "grep -A1 'Subject Key Identifier' '#{client_name}' | tail -n 1 | tr -d ' '"
    ski = `#{get_ski_cmd}`.strip

    get_aki_cmd = "grep -A1 'Authority Key Identifier' '#{client_name}' | tail -n 1 | tr -d ' '"
    aki = `#{get_aki_cmd}`.strip
    client_id = "#{ski}:#{aki}"
  else # if cert does not exist, generate one
    gen_cert_cmd = "./scripts/register_connector.sh #{client_name}"
    gen_cert_cmd_value = `#{gen_cert_cmd}`
    client_id = gen_cert_cmd_value.strip
  end

  keystore_encoded = ""
  Dir.mktmpdir do |d| # create temp directory
    # generate keystore
    cert_to_pem_cmd = "openssl x509 -in keys/#{client_name}.cert -out #{d}/#{client_name}.cert.pem -outform PEM 2>&1"
    `#{cert_to_pem_cmd}`
    export_keystore_cmd = "openssl pkcs12 --password pass:#{keystore_password} -export -in #{d}/#{client_name}.cert.pem -inkey keys/#{client_name}.key -out #{d}/#{client_name}.cert.pfx 2>&1"
    `#{export_keystore_cmd}`

    # encode keystore in base64 for sending via json
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