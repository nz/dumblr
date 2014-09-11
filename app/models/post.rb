class Post < ActiveRecord::Base

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  validates_presence_of :title
  validates_presence_of :body

  def self.published
    where(published: true)
  end

  def self.unpublished
    where('published != ?', true)
  end

  # A more advanced search with highlighting
  # def self.search(query)
  #   __elasticsearch__.search(
  #     {
  #       query: {
  #         multi_match: {
  #           query: query,
  #           fields: ['title^10', 'body']
  #         }
  #       },
  #       highlight: {
  #         pre_tags: ['<em class="label label-highlight">'],
  #         post_tags: ['</em>'],
  #         fields: {
  #           title:   { number_of_fragments: 0 },
  #           body:    { fragment_size: 200 }
  #         }
  #       }
  #     }
  #   )
  # end


end
