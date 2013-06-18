VirtualShelf::Engine.routes.draw do

  get 'caching/google'
  
  resources :records, :only => [:show] do
    get 'before', :on => :member
    get 'after', :on => :member
  end


end
