VirtualShelf::Engine.routes.draw do

  get 'caching/books'
  get 'caching/thumbnails'
  
  resources :records, :only => [:show] do
    get 'before', :on => :member
    get 'after', :on => :member
  end



end
