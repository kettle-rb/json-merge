# frozen_string_literal: true

require "spec_helper"
require "ast/merge/rspec/shared_examples"

RSpec.describe Json::Merge::SmartMerger, "comment behavior matrix", :json_grammar, :mri_backend do
  extend Ast::Merge::RSpec::CommentBehaviorMatrixAdapters

  around do |example|
    TreeHaver.with_backend(:mri) do
      example.run
    end
  end

  it_behaves_like "Ast::Merge::CommentBehaviorMatrix" do
    let(:comment_matrix_default_indent) { "  " }
    let(:comment_matrix_line_equivalents) do
      lambda do |line|
        next [line] unless line.match?(/^\s*"/)

        [line, "#{line},"]
      end
    end
    line_based_comment_matrix_adapter(
      analysis_class: Json::Merge::FileAnalysis,
      merger_class: Json::Merge::SmartMerger,
      capabilities: {},
      source_builder: lambda do |*lines|
        rendered_lines = lines.map(&:dup)
        first_structural_index = rendered_lines.index { |line| line.match?(/^\s*"/) } || rendered_lines.length
        leading_candidates = rendered_lines[0...first_structural_index]
        leading_comment_groups = leading_candidates
          .slice_when { |left, right| left.strip.empty? || right.strip.empty? }
          .map { |group| group.reject { |line| line.strip.empty? } }
          .reject(&:empty?)

        outer_prefix = []
        if leading_comment_groups.length > 1
          split_index = leading_candidates.index { |line| line.strip.empty? } || 0
          split_index += 1 while split_index < leading_candidates.length && leading_candidates[split_index].strip.empty?
          outer_prefix = rendered_lines.shift(split_index)
        end

        structural_indexes = rendered_lines.each_index.select { |index| rendered_lines[index].match?(/^\s*"/) }

        structural_indexes[0...-1].each do |index|
          rendered_lines[index] =
            if rendered_lines[index].include?(" //")
              rendered_lines[index].sub(" //", ", //")
            else
              "#{rendered_lines[index]},"
            end
        end

        inner = rendered_lines.join("\n")
        inner = "#{inner}\n" unless inner.empty?
        prefix = outer_prefix.empty? ? "" : "#{outer_prefix.join("\n")}\n"
        "#{prefix}{\n#{inner}}\n"
      end,
      comment_line_builder: ->(text, indent: comment_matrix_default_indent) { "#{indent}// #{text}" },
      structural_owners_reader: ->(analysis) { analysis.root_pairs },
      owner_value_reader: ->(owner) { owner.value_node&.text },
      line_builder: lambda do |name, value, inline: nil|
        line = %(  "#{name}": #{value})
        inline ? "#{line} // #{inline}" : line
      end,
    )
  end
end
