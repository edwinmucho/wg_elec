Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/keyboard' => 'kakao#keyboard'

  post '/message' => 'kakao#message'

  post '/friend' => 'kakao#friend_add'
  delete '/friend' => 'kakao#friend_del'

  delete '/chat_room/:user_key' => 'kakao#chat_room'

  match ':controller(/:action(/:id))', via: [:get, :post, :patch]
  # get '/hello/view' => 'hello#view'
end
