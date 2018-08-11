# Fast Budget
Tweet-like expense tracker for telegram

## Usage

### Adding transactions
```
14.99 Anna Karenina #books
The Joke #books 14.95 ~2018-08-04
#mortgage 3500
Google Pixel #gadgets 318.96
```

### Querying
```
/stats
```

```
August 2018

#books 14.99
#mortgage 3500
#gadgets 318.96

3,833.95

<prev> - <next>
```

```
/stats #books
```

```
August 2018 #books

04: 14.95 The Joke
11: 14.99 Anna Karenina

29.94

<prev> - <next>
```

## Develop

### Test
```bash
bundle install
bundle exec rake test
```

### Build
```bash
make deploy
make install
sudo systemctl start fast-budgetd
```
