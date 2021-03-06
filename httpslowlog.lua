--[[
Copyright (C) 2015 Luca Marturana

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.


This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

-- Chisel description
description = "Show a log of all HTTP requests slower than latency max_latency";
short_description = "HTTP slow requests log";
category = "Application";
args = {}

require "http"
args =
  {
    {
      name = "max_latency",
      description = "Show requests with latency >= max_latency",
      argtype = "int",
    },
  }

require "common"
-- Argument notification callback
function on_set_arg(name, val)
  if name == "max_latency" then
    max_latency = parse_numeric_input(val, name)
    return true
  end
  return false
end

-- Initialization callback
function on_init()
    http_init()
    -- The -pc or -pcontainer options was supplied on the cmd line
    print_container = sysdig.is_print_container_data()

    return true
end

function on_transaction(transaction)
    if print_container then
        container = " " .. transaction["container"] .. " "
    else
        container = " "
    end
    latency = (transaction["response"]["ts"] - transaction["request"]["ts"])/1000000
    if latency >= max_latency  then
      fmt = string.format("%s%s%s method=%s url=%s response_code=%d latency=%dms size=%dB",
                          evt.field(datetime_field),
                          container,
                          transaction["dir"],
                          transaction["request"]["method"],
                          transaction["request"]["url"],
                          transaction["response"]["code"],
                          latency,
                          transaction["response"]["length"])
      print(fmt)
   end
end

function on_event()
    run_http_parser(evt, on_transaction)
end
