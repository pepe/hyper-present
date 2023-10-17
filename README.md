# hyper-present

Yet another presentation software I have written for my studyblock teachings.

Second time in Janet, this time with `spork/httpf`.

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
