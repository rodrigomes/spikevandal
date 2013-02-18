class Post < ActiveRecord::Base
  attr_accessible :content, :name, :title
  attr_accessible :image
  has_attached_file :image, :styles => { :normal => "1008x1152", :medium => "300x300>", :thumb => "100x100>" }

end
