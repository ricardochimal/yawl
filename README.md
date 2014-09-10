# Yawl

Yawl is **Y**et **a**nother **w**orkflow **l**ibrary.

The target audience is for those who have workflows that are mostly sequential and don't need to create complex branching logic.

## Installation

Add this line to your application's Gemfile:

    gem 'yawl'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yawl

## Usage

The way you go about using it is:

1. You define a set of steps where most of your logic will go

  ```ruby
  Yawl::Steps.set :morning_routine do
    step :first_thing do
      def run
        puts "brush teeth"
      end
    end
  end
  ```
2. You define a process which references set(s) of steps, this will be the name you call when you want to run the process.

  ```ruby
  Yawl::ProcessDefinitions.add(:wake_up) do |process|
    Yawl::Steps.realize_set_on(:morning_routine)
  end
  ```
3. You call the process with the name you defined in step 2, and add any variables that you need to the `Yawl::Process#config` json field.

  ```ruby
  p = Yawl::Process.create(:desired_state => "wake_up", :config => {})
  p.start
  ```

## Running the Example

```
RACK_ENV=examples be rake db:reset db:setup
bundle exec ruby examples/cook_worker.rb &
bundle exec ruby examples/cook.rb
```

## Credit

Originally written by @dpiddy, extracted by @ricardochimal from a larger project into its own gem.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
