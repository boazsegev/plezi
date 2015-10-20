# Plezi's Logging

(todo: write documentation)

Inside Plezi's core code is a pure Ruby IO reactor called [Iodine](https://github.com/boazsegev/iodine), a wonderful Asynchronous Workflow Engine that allows us to enjoy both Multi-Threading and Multi-Processing.

Plezi leverages [Iodine's](https://github.com/boazsegev/iodine) logging support to help you log to both files and STDOUT (terminal screen) - either one or both

You can read more about [Iodine](https://github.com/boazsegev/iodine) and it's amazing features in it's [documentation](http://www.rubydoc.info/github/boazsegev/iodine/master).

## Setting up a Logger

Logging is based on the standard Ruby `Logger`, and replaceing the default logger (STDOUT) to a different logger (such as a file based logger), is as simple as:

```ruby
Iodine.logger = Logger.new filename
```


## Logging Helpers Methods

// to do: complete docs

### `Iodine.info`

// to do: complete docs

### `Iodine.debug`

// to do: complete docs

### `Iodine.warn`

// to do: complete docs

### `Iodine.error`

// to do: complete docs

### `Iodine.fatal`

// to do: complete docs

### `Iodine.log(raw_string)`

// to do: complete docs

