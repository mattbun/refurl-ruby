#!/usr/bin/env ruby

require 'sinatra'
require 'yaml'
require 'filesize'
require 'json'
require 'uri'
require_relative 'db'
require_relative 'config'

db = DB.new
rootpath = ROOT_PATH.chomp("/")
domain = DOMAIN.chomp("/")


helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [AUTH_USER, AUTH_PASS]
  end
end


get '/' do
    return 404
end

get '/that/create' do
    protected!
    @hash = getAHash(db)
    erb :create
end

get '/that/manage' do
    protected!
    erb :manage
end

# API
post '/that/api/create' do
    protected!
    error_message = db.add(rootpath, params["key"], params["name"], params["path"])

    if (error_message != nil)
        result = {:status => "error", :key => params["key"], :error => error_message}
    else
        result = {:status => "ok", :key => params["key"], :url => domain + "/" + params["key"]}
    end

    return JSON.generate(result)
end

get '/that/api/list' do
    protected!
    db.to_json
end

#get '/that/api/ls' do
#    protected!
#    path = params['path']
#    fullpath = rootpath
#    if (path != nil)
#        fullpath += path
#    end
#
#    isDir = File.directory?(fullpath)
#    answer = {:success => true, :isdir => isDir, :path => path}
#
#    if (isDir)
#        answer[:listing] = Dir.entries(fullpath).sort
#    end
#
#    return JSON.generate(answer)
#end

get '/that/api/hash' do 
    protected!
    getAHash(db)
end

delete '/that/api/delete/:key' do |key|
    protected!
    db.delete(key)
    return 200
end

post '/that/jqueryfiletree-connector' do
    protected!
    dir = URI.unescape(params["dir"].to_s)

    fullpath = rootpath
    if (dir != nil)
        fullpath += dir
    end

    return 400 unless (File.expand_path(fullpath).start_with?(File.expand_path(rootpath)))

    filelist = []
    if (File.directory?(fullpath))
        filelist = Dir.entries(fullpath).sort
    end
    
    response = "<ul class=\"jqueryFileTree\" style=\"display: none;\">"

    filelist.each {
        |item|
        next if (item == "." || item == ".." || item == ".AppleDouble")

        if (File.directory?(fullpath + "/" + item))
            response += "<li class=\"directory collapsed\"><a href=\"#\" rel=\"#{dir + item}/\">#{item}</a></li>";
        else
            ext = File.extname(item)[1..-1]
            response += "<li class=\"file ext_#{ext}\"><a href=\"#\" rel=\"#{dir + item}\">#{item}</a></li>"
        end
    }

    response += "</ul>"
    return response
end


get '/:key/download' do |n|
    record = db.get(n)
    halt 404 if (!record)
	if (!File.file?(record.path))
		subpath = params["subpath"]
		halt 404 if (!subpath)
		fullpath = record.path + subpath
		filename = File.basename(fullpath)
		send_file fullpath, :filename => filename, :type => 'Application/octet-stream'
	else
		filename = File.basename(record.path)
		send_file record.path, :filename => filename, :type => 'Application/octet-stream'
	end
end

get '/:key' do |n|
    record = db.get(n)
    halt 404 if (!record)

    @key = n
    @name = record.name
	@size = Filesize.from("#{File.size(record.path)} B").pretty
	@path = record.path.sub(rootpath, "")

	if (!File.file?(record.path))
		erb :downloadfolder
	else
		erb :download
	end
end


def getAHash(db)
    # bubblebabble makes for some fun looking hashes
    require 'digest/bubblebabble'

    counter = 0
    hash = nil
    while (hash == nil || db.hasKey(hash))
        return "" if (counter == 10)
        hashes = (Digest::SHA256.bubblebabble Time.now.to_s + counter.to_s).split("-")
        hash = hashes[rand(hashes.length - 1)]
        counter += 1
    end

    return hash
end
