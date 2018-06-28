require 'sinatra'
require "sinatra/namespace"
require 'mongoid'
require 'sinatra/contrib'

# Models
class Recording
  include Mongoid::Document
  
  store_in collection: "releases"

  field :language
  field :conductor
  field :yearAndRecordingType
  
  embeds_one :composer
  embeds_one :opera
  embeds_many :singers
  embeds_many :editions
  
  scope :conductor, -> (conductor) { where(conductor: /#{conductor}/i) }
  scope :composer, -> (composer) { where('composer.name': /#{composer}/i) }
  scope :singer, -> (singer) { where('singers.name': /#{singer}/i) }
  scope :opera, -> (opera) { where('opera.name': /#{opera}/i) }
  scope :recordType, -> (recordType) { where(yearAndRecordingType: /#{recordType}/i) }
end

class Composer
  include Mongoid::Document

  field :name
end

class Singer
  include Mongoid::Document
  
    field :name
    field :characterName
end

class Opera
  include Mongoid::Document

  field :name
end

class Edition
  include Mongoid::Document
  
  field :medium
  field :reference
end

# Serializers
class RecordingSerializer
  def initialize(recording)
    @recording = recording
  end

  def as_json(*)
    data = {
      id:@recording.id.to_s,
      opera:@recording.opera.name + " (" + @recording.composer.name + ")",
      conductor:@recording.conductor,
      year:@recording.yearAndRecordingType,
      singers:@recording.singers.map { |singer| SingerSerializer.new(singer) }.as_json,
    }
    data[:releases] = @recording.editions.where('medium' => 'cd').first.reference if @recording.editions.where('medium' => 'cd').any?
      
    data[:errors] = @recording.errors if @recording.errors.any?
    data
  end
end

class SingerSerializer
  def initialize(singer)
      @singer = singer
    end
    
    def as_json(*)
      data = {
        name:@singer.name,
        characterName:@singer.characterName
      }
      
      data
    end
end

class EditionSerializer
  def initialize(edition)
      @edition = edition
    end
    
    def as_json(*)
      data = {
        reference:@edition.reference
      }
      
      data
    end
end

class Application < Sinatra::Base
  register Sinatra::Namespace
  
  Mongoid.load! "mongoid.config"
  
  get '/' do
    'Welcome to Recordings!'
  end
  
  namespace '/api/v1' do
  
    before do
      content_type 'application/json'
    end
    
    get '/recordings' do
      recordings = Recording.all
      
      [:conductor,:composer,:recordType,:singer,:opera].each do |filter|
        recordings = recordings.send(filter, params[filter]) if params[filter]
      end
      
      recordings = recordings.sort({ "yearAndRecordingType" => 1}).limit(100)
      
      recordings.map { |recording| RecordingSerializer.new(recording) }.to_json
    end
  
  end
  
end
