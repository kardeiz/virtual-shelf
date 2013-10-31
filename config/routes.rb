VirtualShelf::Engine.routes.draw do

  get 'caching/books'
  get 'caching/thumbnails'
  
  get 'records/:id(/:page)', :to => 'records#show', :as => 'record'



end
