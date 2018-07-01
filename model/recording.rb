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
