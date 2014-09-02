class Post < ActiveRecord::Base

  validates_presence_of :title
  validates_presence_of :body

  def self.published
    where(published: true)
  end

  def self.unpublished
    where('published != ?', true)
  end

end
