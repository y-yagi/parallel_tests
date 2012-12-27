module ParallelTests
  class Grouper
    def self.in_even_groups_by_size(items_with_sizes, num_groups, options = {})
      groups = Array.new(num_groups) { {:items => [], :size => 0} }

      # add all files that should run in a single process to one group
      (options[:single_process] || []).each do |pattern|
        matched, items_with_sizes = items_with_sizes.partition { |item, size| item =~ pattern }
        matched.each { |item, size| add_to_group(groups.first, item, size) }
      end

      groups_to_fill = (options[:isolate] ? groups[1..-1] : groups)

      # add all other files
      largest_first(items_with_sizes).each do |item, size|
        smallest = smallest_group(groups_to_fill)
        add_to_group(smallest, item, size)
      end

      groups.map!{|g| g[:items].sort }
    end

    def self.largest_first(files)
      files.sort_by{|item, size| size }.reverse
    end

    private

    def self.smallest_group(groups)
      groups.min_by{|g| g[:size] }
    end

    def self.add_to_group(group, item, size)
      group[:items] << item
      group[:size] += size
    end

    def self.by_steps(tests, num_groups)
      features_with_steps = build_features_with_steps(tests)
      in_even_groups_by_size(features_with_steps, num_groups)
    end

    def self.build_features_with_steps(tests)
      require 'parallel_tests/cucumber/gherkin_listener'
      listener = Cucumber::GherkinListener.new
      parser = Gherkin::Parser::Parser.new(listener, true, 'root')
      tests.each{|file|
        parser.parse(File.read(file), file, 0)
      }
      listener.collect.sort_by{|_,value| -value }
    end
  end
end
