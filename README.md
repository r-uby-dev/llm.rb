<p align="center">
  <a href="https://r.uby.dev">
    <img
      src="https://github.com/r-uby-dev/llm.rb/raw/main/rubydev.svg"
      width="400"
      height="200"
      border="0"
      alt="a r.uby.dev project"
     >
  </a>
</p>

> A [r.uby.dev](https://r.uby.dev) project.

Welcome to the canonical llm.rb repository.

llm.rb is not a library, framework or toolkit but an advanced runtime
for building highly capable AI applications on CRuby. By default
it has zero runtime dependencies although certain functionality &ndash;
such as ActiveRecord support &ndash; require optional dependencies
that are opt-in.

## Features

The runtime supports OpenAI, OpenAI-compatible endpoints, Anthropic, Google
Gemini, DeepSeek, xAI, Z.ai, AWS Bedrock, Ollama, and llama.cpp.
It has first-class support for streaming, tool calls,  MCP
and A2A, embeddings, vector stores and the RAG pattern.

There are multiple HTTP backends to choose from, tools can be run concurrently
or in parallel via threads, async tasks, fibers, ractors, and fork, and it is
also possible to make a tool call while the model is still streaming.

The runtime builds on top of three core concepts: providers, contexts, and agents,
so once you learn the fundamentals, everything else falls into place naturally. And once
you learn llm.rb, you will also be able to use <a href="https://r.uby.dev/mruby-llm">mruby-llm</a> and
<a href="https://r.uby.dev/wasm-llm">wasm-llm</a> because the API is pretty much identical.

## Install

```bash
gem install llm.rb
```

## Quick start

#### LLM::Agent

The [`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html) class is the default high-level interface,
and it is recommended for most use-cases. It manages tool execution
automatically, guards against infinite loops, manages conversation
state, and much more.

```ruby
require "llm"

llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm, stream: $stdout)
agent.talk "Hello world"
```

#### LLM::Context

The [`LLM::Context`](https://r.uby.dev/api-docs/llm.rb/LLM/Context.html) class is at the heart of the runtime
and it is what [`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html) uses under the hood.
It requires that the tool call loop be managed manually -
sometimes that can be useful, but usually for advanced use-cases.
If you're new to llm.rb, try [`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html) first.

```ruby
require "llm"

llm = LLM.deepseek(key: ENV["KEY"])
ctx = LLM::Context.new(llm, stream: $stdout)
ctx.talk "Hello world"
```

#### LLM::Tool

Subclasses of [`LLM::Tool`](https://r.uby.dev/api-docs/llm.rb/LLM/Tool.html) are plain Ruby classes with
an optional set of typed parameters. <br> The model can choose to
call them on your behalf, and they're one of the most powerful features
for extending the feature set or abilities of a model.

```ruby
class ReadFile < LLM::Tool
  name "read-file"
  description "Read a file"
  parameter :path, String, "The filename or path"
  required %i[path]

  def call(path:)
    {contents: File.read(path)}
  end
end
```

#### LLM::Stream

Streams can be simple IO objects or subclasses of
[`LLM::Stream`](https://r.uby.dev/api-docs/llm.rb/LLM/Stream.html) with structured callbacks for content,
reasoning, tool calls, tool returns, and compaction.

```ruby
class MyStream < LLM::Stream
  def on_content(content)
    print content
  end

  def on_reasoning_content(content)
    warn content
  end
end

llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm, stream: MyStream.new)
agent.talk "Explain Ruby fibers."
```

#### LLM::MCP

The Model Context Protocol (MCP) has first-class support
in llm.rb. The stdio and http transports work out of the
box. MCP tools are translated into subclasses of
[`LLM::Tool`](https://r.uby.dev/api-docs/llm.rb/LLM/Tool.html) that can be used with [`LLM::Context`](https://r.uby.dev/api-docs/llm.rb/LLM/Context.html)
or [`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html).

```ruby
require "llm"

llm   = LLM.deepseek(key: ENV["KEY"])
mcp   = LLM::MCP.stdio(argv: ["ruby", "server.rb"])
agent = LLM::Agent.new(llm, stream: $stdout, tools: mcp.tools)
agent.talk "Run the tool"
```

#### LLM::A2A

The Agent 2 Agent (A2A) protocol has first-class support
in llm.rb. The http and jsonrpc transports work out of the
box. A2A skills are translated into subclasses of
[`LLM::Tool`](https://r.uby.dev/api-docs/llm.rb/LLM/Tool.html) that can be used with [`LLM::Context`](https://r.uby.dev/api-docs/llm.rb/LLM/Context.html)
or [`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html).

```ruby
require "llm"

llm   = LLM.deepseek(key: ENV["KEY"])
a2a   = LLM::A2A.rest(url: "https://remote-agent.example.com")
agent = LLM::Agent.new(llm, stream: $stdout, tools: a2a.tools)
agent.talk "Run the skill"
```

#### RAG

Most providers offer an embedding model that can be
used for semantic search, or similarity search. An
embedding model can generate embeddings that can then
be stored in a database that is optimized for storing
and querying vectors, such as SQLite's [sqlite-vec](https://github.com/asg017/sqlite-vec)
or PostgreSQL's [pg-vector](https://github.com/pgvector/pgvector).

llm.rb also includes support for OpenAI's vector store API. It
provides a vector database as a HTTP service but we won't cover
that here.

```ruby
require "llm"

llm  = LLM.openai(key: ENV["KEY"])
body = "llm.rb is Ruby's capable AI runtime."
embedding = llm.embed([body]).embeddings.first

Document.create!(
  title: "llm.rb",
  body:,
  embedding:,
)
```

#### Concurrency

The runtime supports five different concurrency strategies that have
different attributes. The choice between all of them often depends
on the requirements of your application.

IO-bound tools are a good fit for the `:task`, `:thread`,
and `:fiber` strategies while true parallelism can be achieved
with the `:fork` and `:ractor` strategies. The
`:fork` strategy also provides a separate process that offers
isolation from its parent.

```ruby
require "llm"

llm   = LLM.deepseek(key: ENV["KEY"])
tools = [FetchNews, FetchStocks, FetchFeeds]
agent = LLM::Agent.new(llm, tools:, concurrency: :fork)
agent.talk "Run the tools in parallel"
```

## Extra

#### REPL

This example uses [`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html)
for an interactive REPL. <br> See the
[deepdive (web)](https://r.uby.dev/llm/) or
[deepdive (markdown)](resources/deepdive.md) for more examples.

```ruby
require "llm"

llm = LLM.openai(key: ENV["KEY"])
agent = LLM::Agent.new(llm, stream: $stdout)

loop do
  print "> "
  agent.talk(STDIN.gets || break)
  puts
end
```

#### Multimodal: Local Files

In llm.rb, a prompt can be a string, an [`LLM::Prompt`](https://r.uby.dev/api-docs/llm.rb/LLM/Prompt.html), or an array.
When you use an array, each element can be plain text or a tagged object such as
[`agent.image_url(...)`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html#image_url-instance_method),
[`agent.local_file(...)`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html#local_file-instance_method),
or [`agent.remote_file(...)`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html#remote_file-instance_method).
Those tagged objects carry the metadata the provider adapter needs to turn one
Ruby prompt into the provider-specific multimodal request schema.

If the model understands that file type, you can attach a local file directly
with `agent.ask(..., with: path)` instead of uploading it first through a
provider Files API. Under the hood, llm.rb tags the path as a
[`agent.local_file(...)`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html#local_file-instance_method)
object:

```ruby
require "llm"

llm = LLM.openai(key: ENV["KEY"])
agent = LLM::Agent.new(llm)
puts agent.ask("Summarize this document.", with: "README.md").content
```

#### Context Compaction

This example uses [`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html),
[`LLM::Compactor`](https://r.uby.dev/api-docs/llm.rb/LLM/Compactor.html), and
[`LLM::Stream`](https://r.uby.dev/api-docs/llm.rb/LLM/Stream.html) together so
long-lived conversations can summarize older history and expose the lifecycle
through stream hooks. This approach is inspired by General Intelligence
Systems. The
compactor can also use its own `model:` if you want summarization to run on a
different model from the main conversation. `token_threshold:` accepts either a
fixed token count or a percentage string like `"90%"`, which resolves
against the active model context window and triggers compaction once total
token usage goes over that percentage. See the
[deepdive (web)](https://r.uby.dev/llm/) or
[deepdive (markdown)](resources/deepdive.md) for more examples.

```ruby
require "llm"

class Stream < LLM::Stream
  def on_compaction(ctx, compactor)
    puts "Compacting #{ctx.messages.size} messages..."
  end

  def on_compaction_finish(ctx, compactor)
    puts "Compacted to #{ctx.messages.size} messages."
  end
end

llm = LLM.openai(key: ENV["KEY"])
agent = LLM::Agent.new(
  llm,
  stream: Stream.new,
  compactor: {
    token_threshold: "90%",
    retention_window: 8,
    model: "gpt-5.4-mini"
  }
)
```

#### Reasoning

This example uses [`LLM::Stream`](https://r.uby.dev/api-docs/llm.rb/LLM/Stream.html)
with the OpenAI Responses API so reasoning output is streamed separately from
visible assistant output. See the
[deepdive (web)](https://r.uby.dev/llm/) or
[deepdive (markdown)](resources/deepdive.md) for more examples.

To use the Responses API (OpenAI-specific), initialize an agent with
`mode: :responses` and keep using `talk` for turns.

```ruby
require "llm"

class Stream < LLM::Stream
  def on_content(content)
    $stdout << content
  end

  def on_reasoning_content(content)
    $stderr << content
  end
end

llm = LLM.openai(key: ENV["KEY"])
agent = LLM::Agent.new(
  llm,
  model: "gpt-5.4-mini",
  mode: :responses,
  reasoning: { effort: "medium" },
  stream: Stream.new
)
agent.talk("Solve 17 * 19 and show your work.")
```

#### Request Cancellation

Need to cancel a stream? llm.rb has you covered through
[`LLM::Agent#interrupt!`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html#interrupt-21-instance_method).
<br> See the [deepdive (web)](https://r.uby.dev/llm/)
or [deepdive (markdown)](resources/deepdive.md) for more examples.

```ruby
require "llm"
require "io/console"

llm = LLM.openai(key: ENV["KEY"])
agent = LLM::Agent.new(llm, stream: $stdout)
worker = Thread.new do
  agent.talk("Write a very long essay about network protocols.")
rescue LLM::Interrupt
  puts "Request was interrupted!"
end

STDIN.getch
agent.interrupt!
worker.join
```

#### Sequel (ORM)

The `plugin :llm` integration wraps
[`LLM::Context`](https://r.uby.dev/api-docs/llm.rb/LLM/Context.html) on a
`Sequel::Model` and keeps tool execution explicit. Like the ActiveRecord
wrappers, its built-in persistence contract is the serialized `data` column,
while `provider:` resolves a real `LLM::Provider` instance and `context:`
injects defaults such as `model:`. <br> See the
[deepdive (web)](https://r.uby.dev/llm/) or
[deepdive (markdown)](resources/deepdive.md) for more examples.

```ruby
require "llm"
require "net/http/persistent"
require "sequel"
require "sequel/plugins/llm"

class Context < Sequel::Model
  plugin :llm, provider: :set_provider, context: :set_context

  private

  def set_provider
    LLM.openai(key: ENV["OPENAI_SECRET"], persistent: true)
  end

  def set_context
    { model: "gpt-5.4-mini", mode: :responses, store: false }
  end
end

ctx = Context.create
ctx.talk("Remember that my favorite language is Ruby")
puts ctx.talk("What is my favorite language?").content
```

#### ActiveRecord (ORM): acts_as_llm

The `acts_as_llm` method wraps [`LLM::Context`](https://r.uby.dev/api-docs/llm.rb/LLM/Context.html) and
provides full control over tool execution. Its built-in persistence contract is
one serialized `data` column. If your app has provider, model, or usage
columns, provide them to llm.rb through `provider:` and `context:` instead of
relying on reserved wrapper columns.

See the [deepdive (web)](https://r.uby.dev/llm/)
or [deepdive (markdown)](resources/deepdive.md) for more examples.

```ruby
require "llm"
require "active_record"
require "llm/active_record"

class Context < ApplicationRecord
  acts_as_llm provider: :set_provider, context: :set_context

  private

  def set_provider
    LLM.openai(key: ENV["OPENAI_SECRET"])
  end

  def set_context
    { model: "gpt-5.4-mini", mode: :responses, store: false }
  end
end

ctx = Context.create!
ctx.talk("Remember that my favorite language is Ruby")
puts ctx.talk("What is my favorite language?").content
```

```ruby
require "llm"
require "active_record"
require "llm/active_record"

class Context < ApplicationRecord
  acts_as_llm provider: :set_provider, context: :set_context

  # Optional application columns can still provide the provider and context.
  # For example, `provider_name` and `model_name` can be normal columns.

  private

  def set_provider
    LLM.public_send(provider_name, key: provider_key)
  end

  def set_context
    { model: model_name, mode: :responses, store: false }
  end
end
```

#### ActiveRecord (ORM): acts_as_agent

The `acts_as_agent` method wraps [`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html) and
manages tool execution for you. Like `acts_as_llm`, its built-in persistence
contract is one serialized `data` column. If your app has provider or model
columns, provide them to llm.rb through your hooks and agent DSL.

See the [deepdive (web)](https://r.uby.dev/llm/)
or [deepdive (markdown)](resources/deepdive.md) for more examples.

```ruby
require "llm"
require "active_record"
require "llm/active_record"

class Ticket < ApplicationRecord
  acts_as_agent provider: :set_provider, context: :set_context
  model "gpt-5.4-mini"
  instructions "You are a concise support assistant."
  tools SearchDocs, Escalate
  concurrency :thread

  private

  def set_provider
    LLM.openai(key: ENV["OPENAI_SECRET"])
  end

  def set_context
    { mode: :responses, store: false }
  end
end

ticket = Ticket.create!
puts ticket.talk("How do I rotate my API key?").content
```

```ruby
require "llm"
require "active_record"
require "llm/active_record"

class Ticket < ApplicationRecord
  acts_as_agent provider: :set_provider, context: :set_context
  model "gpt-5.4-mini"
  instructions "You are a concise support assistant."

  private

  def set_provider
    LLM.public_send(provider_name, key: provider_key)
  end

  def set_context
    { mode: :responses, store: false }
  end
end
```

#### MCP

This example uses [`LLM::MCP`](https://r.uby.dev/api-docs/llm.rb/LLM/MCP.html)
over HTTP so remote GitHub MCP tools run through the same
`LLM::Agent` tool path as local tools. It expects a GitHub token in
`ENV["GITHUB_PAT"]`. See the
[deepdive (web)](https://r.uby.dev/llm/) or
[deepdive (markdown)](resources/deepdive.md) for more examples.

```ruby
require "llm"
require "net/http/persistent"

llm = LLM.openai(key: ENV["KEY"], persistent: true)
mcp = LLM::MCP.http(
  url: "https://api.githubcopilot.com/mcp/",
  headers: { "Authorization" => "Bearer " + ENV["GITHUB_PAT"].to_s },
  persistent: true
)

agent = LLM::Agent.new(llm, stream: $stdout, tools: mcp.tools)
agent.talk("Pull information about my GitHub account.")
```

## License

[BSD Zero Clause](https://choosealicense.com/licenses/0bsd/)
<br>
See [LICENSE](./LICENSE)
