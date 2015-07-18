require 'spec_helper'

describe Rinflux::Client do
  describe '@options' do
    subject { rinflux(options).instance_variable_get(:@options) }
    let(:options) { {} }

    context 'default' do
      it do
        is_expected.to eq(:url=>"http://localhost:8086")
      end
    end

    context 'specify host' do
      let(:options) { {host: '127.0.0.1'} }

      it do
        is_expected.to eq(:url=>"http://127.0.0.1:8086")
      end
    end

    context 'specify port' do
      let(:options) { {port: 8087} }

      it do
        is_expected.to eq(:url=>"http://localhost:8087")
      end
    end
  end

  describe '#query' do
    subject { client.query(query, options) }

    let(:options) { {} }

    let(:client) do
      rinflux do |stub|
        stub.get('query') do |env|
          expect(env.url.query).to eq expected_query
          [200, {'Content-Type' => 'application/json'}, JSON.dump(response)]
        end
      end
    end

    context 'select' do
      let(:response) do
        {"results"=>
          [{"series"=>
             [{"name"=>"cpu_load_short",
               "tags"=>{"host"=>"server01", "region"=>"us-west"},
               "columns"=>["time", "value"],
               "values"=>[["2015-01-29T21:51:28.968422294Z", 0.64]]}]}]}
      end

      let(:query) { "SELECT value FROM cpu_load_short WHERE region='us-west'" }
      let(:options) { {db: :mydb} }

      let(:expected_query) do
        "db=mydb&q=SELECT+value+FROM+cpu_load_short+WHERE+region%3D%27us-west%27"
      end

      it do
        is_expected.to eq response
      end
    end

    context 'create' do
      let(:response) do
        {"results"=>[{}]}
      end

      let(:query) { "CREATE DATABASE mydb" }

      let(:expected_query) do
        "q=CREATE+DATABASE+mydb"
      end

      it do
        is_expected.to eq response
      end
    end
  end

  describe '#write' do
    subject do
      body = nil

      rinflux {|stub|
        stub.post('write') do |env|
          expect(env.url.query).to eq expected_query
          body = env.body
          [204, {}, '']
        end
      }.write(measurement, value, options)

      body
    end

    context 'Simplest Valid Point (measurement + field)' do
      let(:measurement) { :disk_free }
      let(:value) { 442221834240 }
      let(:options) { {db: :mydb} }

      let(:expected_query) { "db=mydb" }

      it do
        is_expected.to eq "disk_free value=442221834240"
      end
    end

    context 'With Timestamp' do
      let(:measurement) { :disk_free }
      let(:value) { 442221834240 }

      let(:options) do
        {
          db: :mydb,
          timestamp: 1435362189575692182
        }
      end

      let(:expected_query) { "db=mydb" }

      it do
        is_expected.to eq "disk_free value=442221834240 1435362189575692182"
      end
    end

    context 'With Timestamp (Time class)' do
      let(:measurement) { :disk_free }
      let(:value) { 442221834240 }

      let(:options) do
        {
          db: :mydb,
          timestamp: Time.at(1435362189, 575692)
        }
      end

      let(:expected_query) { "db=mydb" }

      it do
        is_expected.to eq "disk_free value=442221834240 1435362189575692000"
      end
    end

    context 'With Tags' do
      let(:measurement) { :disk_free }
      let(:value) { 442221834240 }

      let(:options) do
        {
          db: :mydb,
          tags: {hostname: 'server01', disk_type: 'SSD'},
          timestamp: 1435362189575692182
        }
      end

      let(:expected_query) { "db=mydb" }

      it do
        is_expected.to eq "disk_free,hostname=server01,disk_type=SSD value=442221834240 1435362189575692182"
      end
    end

    context 'Multilple Fields' do
      let(:measurement) { :disk_free }
      let(:value) do
        {
          free_space: 442221834240,
          disk_type: "SSD"
        }
      end

      let(:options) do
        {
          db: :mydb,
          tags: {hostname: 'server01', disk_type: 'SSD'},
          timestamp: 1435362189575692182
        }
      end

      let(:expected_query) { "db=mydb" }

      it do
        is_expected.to eq 'disk_free,hostname=server01,disk_type=SSD free_space=442221834240,disk_type="SSD" 1435362189575692182'
      end
    end

    context 'Escaping Commas and Spaces' do
      let(:measurement) { 'total disk free' }
      let(:value) { 442221834240 }

      let(:options) do
        {
          db: :mydb,
          tags: {volumes: '/net,/home,/'},
          timestamp: 1435362189575692182
        }
      end

      let(:expected_query) { "db=mydb" }

      it do
        is_expected.to eq 'total\ disk\ free,volumes=/net\,/home\,/ value=442221834240 1435362189575692182'
      end
    end

    context 'With Backslash in Tag Value' do
      let(:measurement) { :disk_free }
      let(:value) { 442221834240 }

      let(:options) do
        {
          db: :mydb,
          tags: {path: 'C:\Windows'}
        }
      end

      let(:expected_query) { "db=mydb" }

      it do
        is_expected.to eq 'disk_free,path=C:\Windows value=442221834240'
      end
    end

    context 'Escaping Field Key' do
      let(:measurement) { :disk_free }

      let(:value) do
        {
          :value => 442221834240,
          'working directories' => 'C:\My Documents\Stuff for examples,C:\My Documents'
        }
      end

      let(:options) do
        {
          db: :mydb
        }
      end

      let(:expected_query) { "db=mydb" }

      it do
        is_expected.to eq 'disk_free value=442221834240,working\ directories="C:\My Documents\Stuff for examples,C:\My Documents"'
      end
    end

    context 'Showing all escaping and quoting behavior' do
      let(:measurement) { 'measurement with quotes' }

      let(:value) do
        {
          'field_key\\\\\\\\' => 'string field value, only " need be quoted'
        }
      end

      let(:options) do
        {
          db: :mydb,
          tags: {'tag key with spaces' => 'tag,value,with"commas"'}
        }
      end

      let(:expected_query) { "db=mydb" }

      it do
        is_expected.to eq 'measurement\ with\ quotes,tag\ key\ with\ spaces=tag\,value\,with"commas" field_key\\\\\\\\="string field value, only \" need be quoted"'
      end
    end
  end
end
