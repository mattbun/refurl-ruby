#!/usr/bin/env ruby

require 'sinatra'
require 'yaml'
require_relative 'db'

db = DB.new

#get '/' do
#    erb :index
#end

get '/manage' do
    erb :manage
end

post '/manage/add' do
    db.add(params["key"], Record.new(params["key"], params["name"], params["path"], ""))
end

get '/download/:key' do |n|
    record = db.get(n)
    filename = File.basename(record.path)
    send_file record.path, :filename => filename, :type => 'Application/octet-stream'
end

get '/:key' do |n|
    record = db.get(n)
    if (!record) then
        halt 404
    end

    @key = n
    @name = record.name
    @size = record.size
    erb :download
end
