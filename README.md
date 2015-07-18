# Rinflux

It is unofficial low level ruby client library for InfluxDB.

The official client is [here](https://github.com/influxdb/influxdb-ruby).

[![Build Status](https://travis-ci.org/winebarrel/rinflux.svg?branch=master)](https://travis-ci.org/winebarrel/rinflux)

## Installation

```sh
git clone https://github.com/winebarrel/rinflux.git
cd rinflux
bundle install
bundle exec rake install
```

## Usage

```ruby
require 'rinflux'

client = Rinflux::Client.new
#client = Rinflux::Client.new(host: 'localhost', port: 8086)
```

### Querying Data

```ruby
client.query(
  "SELECT value FROM cpu_load_short WHERE region='us-west'"
  db: :mydb
)
#=> {"results"=>
#     [{"series"=>
#        [{"name"=>"cpu_load_short",
#          "tags"=>{"host"=>"server01", "region"=>"us-west"},
#          "columns"=>["time", "value"],
#          "values"=>[["2015-01-29T21:51:28.968422294Z", 0.64]]}]}]}
```

### Writing Data
```ruby
client.write(
  :disk_free,   # measurement
  442221834240, # value
  {
    db: :mydb,
    tags: {hostname: 'server01', disk_type: 'SSD'},
    timestamp: Time.at(1435362189, 575692)
  }
)
#=> "disk_free,hostname=server01,disk_type=SSD value=442221834240 1435362189575692000"
```
```ruby
client.write(
  :disk_free,   # measurement
  {
    free_space: 442221834240,
    disk_type: "SSD"
  },
  {
    db: :mydb,
    tags: {hostname: 'server01', disk_type: 'SSD',
    timestamp: 1435362189575692182
  }
)
#=> 'disk_free,hostname=server01,disk_type=SSD free_space=442221834240,disk_type="SSD" 1435362189575692182'a
```

## Related links

* [Writing Data | InfluxDB](https://influxdb.com/docs/v0.9/guides/writing_data.html)
* [Querying Data | InfluxDB](https://influxdb.com/docs/v0.9/guides/querying_data.html)
* [Line Protocol | InfluxDB](https://influxdb.com/docs/v0.9/write_protocols/line.html)
* [Line Protocol Syntax Reference | InfluxDB](https://influxdb.com/docs/v0.9/write_protocols/write_syntax.html)
