# define a set of steps

Yawl::Steps.set :scrambled_eggs do
  step :buy_eggs do
    def run
      puts "bought a dozen eggs at the market"
    end
  end

  step :put_pan_on_stove do
    def run
      puts "put a non-stick pan on the stove"
    end
  end

  step :turn_on_heat_to_medium do
    def run
      puts "turn on heat to medium"
    end
  end

  step :crack_eggs_and_scramble do
    def run
      puts "crack eggs on pan and scramble"
    end
  end

  step :serve do
    def run
      puts "you just got served"
    end
  end
end

# Define a process definition and which set of steps should belong to the process
Yawl::ProcessDefinitions.add(:scrambled_eggs) do |process|
  Yawl::Steps.realize_set_on(:scrambled_eggs, process)
end
