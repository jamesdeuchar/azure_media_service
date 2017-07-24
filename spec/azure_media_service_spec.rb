require 'spec_helper'
require 'azure_media_service'

RSpec.configure do |config|
  config.before(:all) do
    raise "No AMS_TEST_ACCOUNT env var found!" if ENV['AMS_TEST_ACCOUNT'].nil? || ENV['AMS_TEST_ACCOUNT'].empty?
    raise "No AMS_TEST_ACCOUNT_KEY env var found!" if ENV['AMS_TEST_ACCOUNT_KEY'].nil? || ENV['AMS_TEST_ACCOUNT_KEY'].empty?
    @account = AzureMediaService::Account.new(ENV['AMS_TEST_ACCOUNT'], ENV['AMS_TEST_ACCOUNT_KEY'], ENV['AMS_TEST_PROXY_URL'])
  end
  
end

def get_operation_result(operation_id)
  operation = nil
  while (true)
    if operation = @account.operation(operation_id)
      case operation['State']
      when 'Succeeded'
        return operation['State']
      when 'Failed'
        return operation['State']
      end
    else
      raise "Failed to get operation status!"
    end
    sleep 5
  end
  return operation
end

describe 'Channels' do
  channel_id = nil
  acl = [{'Name' => 'Test ACL', 'Address' => '1.1.1.1', 'SubnetPrefixLength' => 32}]
  it "create channel" do
    channel, operation_id = @account.create_channel('TestChannel', {'Description' => 'TestChannel Description'})
    expect(get_operation_result(operation_id)).to eq('Succeeded')
    channel_id = channel.Id
  end
  it "list channels" do 
    channels = @account.channels
    expect(channels).not_to be_empty
  end
  it "get channel" do
    channel = @account.channels(channel_id)
    expect(channel.Id).to eq(channel_id)
  end
  it "get channel input acls" do
    channel = @account.channels(channel_id)
    acls = channel.get_input_acls
    expect(acls).not_to be_empty
  end
  it "set channel input acls" do
    channel = @account.channels(channel_id)
    response = channel.set_input_acls(acl)
    expect(response).to be_empty
  end
  it "set channel preview acls" do
    channel = @account.channels(channel_id)
    response = channel.set_preview_acls(acl)
    expect(response).to be_empty
  end
  it "get channel preview acls" do
    channel = @account.channels(channel_id)
    acls = channel.get_preview_acls
    expect(acls).not_to be_empty
  end
  it "start" do
    channel = @account.channels(channel_id)
    response, operation_id = channel.start
    expect(get_operation_result(operation_id)).to eq('Succeeded')
  end
  it "reset" do
    channel = @account.channels(channel_id)
    response, operation_id = channel.reset
    expect(get_operation_result(operation_id)).to eq('Succeeded')
  end
  it "stop" do
    channel = @account.channels(channel_id)
    response, operation_id = channel.stop
    expect(get_operation_result(operation_id)).to eq('Succeeded')
  end
  it "Delete" do
    channel = @account.channels(channel_id)
    response, operation_id = channel.delete
    expect(get_operation_result(operation_id)).to eq('Succeeded')
  end
end

describe 'StreamingEndpoint' do
  se_id = nil
  acl = [{'Name' => 'Test ACL', 'Address' => '1.1.1.1', 'SubnetPrefixLength' => 32}]
  it "create streaming endpoint" do
    se, operation_id = @account.create_streamingendpoint('TestEndpoint', {'Description' => 'TestEndpoint Description'})
    expect(get_operation_result(operation_id)).to eq('Succeeded')
    se_id = se.Id
  end
  it "list streaming endpoints", :focus do 
    streamingendpoints = @account.streamingendpoints
    expect(streamingendpoints).not_to be_empty
  end
  it "get streaming endpoint" do
    streamingendpoint = @account.streamingendpoints(se_id)
    expect(streamingendpoint.Id).to eq(se_id)
  end
  it "set streaming endpoint output acls" do
    streamingendpoint = @account.streamingendpoints(se_id)
    response = streamingendpoint.set_output_acls(acl)
    expect(response).to be_empty
  end
  it "get channel output acls" do
    streamingendpoint = @account.streamingendpoints(se_id)
    acls = streamingendpoint.get_output_acls
    expect(acls).not_to be_empty
  end
  it "start" do
    streamingendpoint = @account.streamingendpoints(se_id)
    response, operation_id = streamingendpoint.start
    expect(get_operation_result(operation_id)).to eq('Succeeded')
  end
  it "stop" do
    streamingendpoint = @account.streamingendpoints(se_id)
    response, operation_id = streamingendpoint.stop
    expect(get_operation_result(operation_id)).to eq('Succeeded')
  end
  it "Delete" do
    streamingendpoint = @account.streamingendpoints(se_id)
    response, operation_id = streamingendpoint.delete
    expect(get_operation_result(operation_id)).to eq('Succeeded')
  end
end

# describe 'Programs' do
#   context "List" do
#     pending
#   end
#   context "Create" do
#     pending
#   end
#   context "Start" do
#     pending
#   end
#   context "Stop" do
#     pending
#   end
#   context "Reset" do
#     pending
#   end
#   context "Delete" do
#     pending
#   end
# end
#
# describe 'Asset' do
#   context "List" do
#     pending
#   end
#   context "Create" do
#     pending
#   end
#   context "Delete" do
#     pending
#   end
# end
#
# describe 'StreamingEndpoint' do
#   context "List" do
#     pending
#   end
#   context "Create" do
#     pending
#   end
#   context "Start" do
#     pending
#   end
#   context "Scale" do
#     pending
#   end
#   context "Stop" do
#     pending
#   end
#   context "Delete" do
#     pending
#   end
# end