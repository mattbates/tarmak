# get_ipaddress_in_network
module Puppet::Parser::Functions
  newfunction(:get_ipaddress_in_network, :type => :rvalue) do |args|

    if (args.size != 1) then
      raise(
        Puppet::ParseError,
        "get_ipaddress_in_network(): Wrong number of arguments got: #{args.size} expected: 1",
      )
    end

    interfaces = lookupvar('interfaces')

    # If we do not have any interfaces, then there are no requested attributes
    return :undefined if (interfaces == :undefined || interfaces.nil?)

    interfaces = interfaces.split(',')

    begin
      network = IPAddr.new(args[0])
      interfaces.each do |iface|
        begin
          ip = IPAddr.new(lookupvar("ipaddress_#{iface}"))
          return ip.to_s if network.include? ip
        rescue ArgumentError
          continue
        end
      end
    rescue ArgumentError
      raise(
        Puppet::ParseError,
        "get_ipaddress_in_network(): invalid network: #{args[0]}"
      )
    end
    return :undefined
  end
end
