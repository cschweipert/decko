# -*- encoding : utf-8 -*-

RSpec.describe Card::View::Classy do
  it "doesn't change on the same level" do
    format =
      Card["A"].format_with do
        view :test do
          [render_a, render_b].join ";"
        end

        view :a do
          class_up "down", "up"
          "a:#{classy "down"}"
        end
        view(:b) { "b:#{classy "down"}" }
      end
    expect(format.render_test).to eq "a:down up;b:down"
  end

  it "changes all nested" do
    format =
      Card["A"].format_with do
        view :test do
          class_up "down", "up"
          [render_a, render_b].join ";"
        end

        view(:a) { "a:#{classy "down"}" }
        view(:b) { "b:#{classy "down"}" }
      end
    expect(format.render_test).to eq "a:down up;b:down up"
  end

  it "changes only self with self option" do
    format =
      Card["A"].format_with do
        view :test do
          class_up "down", "up", true, :self
          ["test:#{classy "down"}", render_a].join ";"
        end

        view(:a) { "a:#{classy "down"}" }
      end
    expect(format.render_test).to eq "test:down up;a:down"
  end
end
