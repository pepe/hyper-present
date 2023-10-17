# hyper-present

Yet another presentation software I have written for my studyblock teachings.

Second time in Janet, this time with `spork/httpf` and Hypermedia systems
(htmx, hyperscript).

## Usage

Install dependencies:

```
jpm -l deps
```

Run the server once:

```
jpm -l janet ./hyper-present/init.janet ./presentation.md
```

Watch files and restart the server on the change:

```
jpm -l janet ./bin/dev.janet ./presentation.md
```

## Plans

As part of the summer semester studyblock oriented on backend development,
I would like to add:

- SSE
- Roles: speaker, student
- More multimedia
- Janet playground
- State persistence
