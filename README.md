# Rails Cafe API

## Goal - Back End
Build a Rails application that acts solely as an API. Instead of displaying HTML pages, it'll render JSON.

<img width="1734" height="1370" alt="image" src="https://github.com/user-attachments/assets/c401e629-3b40-4f5b-9e75-99bfeec5a5e4" />

## Goal - Front End
In a separate git repository, i'll build a React application to consume this API.
<img width="3024" height="1716" alt="image" src="https://github.com/user-attachments/assets/263dc74f-5321-4a8d-8a74-d5cc72cae4ea" />

## Create the application
```
rails new rails-cafe-api -d postgresql --api
```
With the --api flag, there are 3 main differences:

• Configure your application to start with a more limited set of middleware than normal. Specifically, it will not include any middleware primarily useful for browser applications (like cookies support) by default.
• Make ApplicationController inherit from ActionController::API instead of ActionController::Base. As with middleware, this will leave out any Action Controller modules that provide functionalities primarily used by browser applications.
• Configure the generators to skip generating views, helpers, and assets when you generate a new resource.

## Create Github repository
```
gh repo create rails-cafe-api --public --source=.
```
## Designing the DB
<img width="216" height="358" alt="image" src="https://github.com/user-attachments/assets/a32d97ec-37ec-42e5-b910-95c4bf711d3b" />

## Creating the Model
Create the DB before the model
```
rails db:create
```
⚠️ Small warning about pluralization in Rails
• The pluralization is built in to handle things like person => people and sky => skies etc.
So let's go into our config/initializers/inflections.rb and add this:
```
ActiveSupport::Inflector.inflections do |inflect|
  inflect.plural "cafe", "cafes"
end
```
Then create the model
```
rails g model cafe title:string address:string picture:string hours:jsonb criteria:string
```
Create the criteria array
```
t.string :criteria, array: true
```
Then run the migration and our DB should be ready to go.

```
rails db:migrate
```

## Setting up the Model
Validations on the cafe model
```
# cafe.rb
validates :title, presence: true, uniqueness: { scope: :address }
validates :address, presence: true
```

## Seeds

```
require 'open-uri'

puts "Removing all cafes from the DB..."
Cafe.destroy_all
puts "Getting the cafes from the JSON..."
seed_url = 'https://gist.githubusercontent.com/yannklein/5d8f9acb1c22549a4ede848712ed651a/raw/3daec24bcd833f0dd3bcc8cee8616a731afd1f37/cafe.json'
# Making an HTTP request to get back the JSON data
json_cafes = URI.open(seed_url).read
# Converting the JSON data into a ruby object (this case an array)
cafes = JSON.parse(json_cafes)
# iterate over the array of hashes to create instances of cafes
cafes.each do |cafe_hash|
  puts "Creating #{cafe_hash['title']}..."
  Cafe.create!(
    title: cafe_hash['title'],
    address: cafe_hash['address'],
    picture: cafe_hash['picture'],
    criteria: cafe_hash['criteria'],
    hours: cafe_hash['hours']
  )
end
puts "... created #{Cafe.count} cafes! ☕️"
```
Run the seeds rails db:seed and have a look in the rails console to see our cafes.

## Routes
```
get '/api/v1/cafes'
```
```
post '/api/v1/cafes'
```
Namespace in routes.rb
```
namespace :api, defaults: { format: :json } do
  namespace :v1 do
    resources :cafes, only: [ :index, :create ]
  end
end
```
## Controller Actions
Starting with index
```
def index
  @cafes = Cafe.all
end
```
If we allow users to search for cafes by their title in our app, we can add that into our action as well:

```
def index
  if params[:title].present?
    @cafes = Cafe.where('title ILIKE ?', "%#{params[:title]}%")
  else
    @cafes = Cafe.all
  end
end
```
BUT, this is the biggest difference from building an API compared to one with HTML views. Instead of rendering HTML, we're going to render JSON.
```
def index
  if params[:title].present?
    @cafes = Cafe.where('title ILIKE ?', "%#{params[:title]}%")
  else
    @cafes = Cafe.all
  end
  # Putting the most recently created cafes first
  render json: @cafes.order(created_at: :desc)
end
```

## POSTMAN
<img width="2766" height="1706" alt="image" src="https://github.com/user-attachments/assets/2509581e-f7e0-46de-a071-5cf513621ab0" />
equest code:
```
{
  "cafe": {
    "title": "Le Wagon Tokyo",
    "address": "2-11-3 Meguro, Meguro City, Tokyo 153-0063",
    "picture": "https://www-img.lewagon.com/wtXjAOJx9hLKEFC89PRyR9mSCnBOoLcerKkhWp-2OTE/rs:fill:640:800/plain/s3://wagon-www/x385htxbnf0kam1yoso5y2rqlxuo",
    "criteria": ["Stable Wi-Fi", "Power sockets", "Coffee", "Food"],
    "hours": {
      "Mon": ["10:30 – 18:00"],
      "Tue": ["10:30 – 18:00"],
      "Wed": ["10:30 – 18:00"],
      "Thu": ["10:30 – 18:00"],
      "Fri": ["10:30 – 18:00"],
      "Sat": ["10:30 – 18:00"]
    }
  }
}
```
Controller
```
def create
  @cafe = Cafe.new(cafe_params)
  if @cafe.save
    render json: @cafe, status: :created
  else
    render json: { error: @cafe.errors.messages }, status: :unprocessable_entity
  end
end

private

def cafe_params
  params.require(:cafe).permit(:title, :address, :picture, hours: {}, criteria: [])
end
```

## CORS
Specific
```
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://example.com:80'
    resource '/orders',
      :headers => :any,
      :methods => [:post]
  end
end
```
Allow all
```
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :patch, :put]
  end
end
```
