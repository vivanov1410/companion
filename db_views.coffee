# '_design/users'
## 'all'
(doc) ->
  if doc.type is 'user'
    user = doc.meta
    emit user.username, user

# '_design/expenses'
## 'all'
(doc) ->
  if doc.type is 'expense'
    expense = doc.meta
    emit expense.date, expense