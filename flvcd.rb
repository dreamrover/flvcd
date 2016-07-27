#!/usr/bin/ruby

require 'net/http'
require 'open-uri'
#require 'nokogiri'

#url = 'http://tv.cntv.cn/video/C10302/07684459530844518a7257ee7123fd1e'
#url = "http://tv.cntv.cn/video/C10302/969ff85e8150498b94d140206fd2cf33"

def parse_url(url)
    doc = Net::HTTP.get(URI('http://www.flvcd.com/parse.php?kw=' + url))
    row = ''
    doc.lines do |line|
        if line =~ /<BR><a href="http:\/\/.*\.mp4"/
            row = line.lstrip!.b
            break
        end
    end
#puts row[%r{"http://.+?\.mp4"}]
    links = []
    row.scan(%r{"http://.+?\.mp4"}) {|link| links.push(link[1..-2])}
    links.each {|l| puts l}
    links
end

def fetch_file(link)
    host = link.match(%r{http://.+?/}).to_s
    path = link[host.length-1..-1]
    host = host[7...-1]
    port = host.match(/:\d+/).to_s
    host = host.split(port)[0] if port!=""
    port = port=="" ? 80 : port[1..-1]
    name = link.match(/[^\/\.]+\.mp4/).to_s
    puts host, port, path, name
    down = 0
    down = File.stat(name).size if File.exist?(name)
    initheader = nil
'''
    response = http.request_head(path)
    length = response["content-length"].to_i
    return down if down == length

    down = 0 if down > length
    initheader = {"Range" => "bytes=#{down}-"} if down < length
'''
    http = Net::HTTP.new(host, port)
    http.request_get(path, initheader) do |resp|
        resp.header.each_header {|k, v| puts "#{k} = #{v}"}
        if resp.code =~ /30[1237]/
            fetch_file(resp["location"].to_s)
            break
        end
        length = resp["content-length"].to_i
        begin
            file = File.new(name, down > 0 ? "a":"w")
            puts name
            resp.read_body do |seg|
                file.write(seg)
                down += seg.length
                printf("\rdownloading %d/%d", down, length)
            end
        ensure
            file.close()
        end
        puts " done", "============================================" if down==length
    end
    down
end

url = ARGV[0]
parse_url(url).each {|link| fetch_file(link)}

