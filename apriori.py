import pandas as pd
import numpy as np
import pyodbc 
from mlxtend.frequent_patterns import association_rules, apriori
import sqlalchemy

conn = pyodbc.connect('Driver={SQL Server};'
                      'Server=DESKTOP-43VILRD;'
                      'Database=Northwind;'
                      'Trusted_Connection=yes;')

df = pd.read_sql_query('SELECT OrderId , ProductName , Quantity FROM [Order] INNER JOIN [OrderItem] ON [OrderItem].OrderId  = [Order].Id INNER JOIN [Product] ON [Product].Id =[OrderItem].ProductId', conn)
distinct_orders = pd.read_sql_query('SELECT OrderId FROM [Order]INNER JOIN [OrderItem] ON [OrderItem].OrderId  = [Order].Id INNER JOIN [Product] ON [Product].Id =[OrderItem].ProductId GROUP BY OrderId HAVING COUNT(ProductId)=1', conn)

distinct_orders_list = distinct_orders["OrderId"].tolist()


for i in df["OrderId"]:
    if i in distinct_orders_list:
        df = df.loc[df["OrderId"] != i]
print(len(df))

basket = df.groupby(['OrderId' , 'ProductName'])['Quantity'].sum().unstack().reset_index().fillna(0).set_index('OrderId')


def hot_encode(x):
    if(x<= 0):
        return 0
    if(x>= 1):
        return 1


basket_result = basket.applymap(hot_encode)
basket = basket_result





frq_items = apriori(basket, min_support = 0.01, use_colnames = True)
rules = association_rules(frq_items, metric ="confidence", min_threshold = 0.1)
rules = rules.sort_values(['confidence', 'lift'], ascending =[False, False])

print(rules)

# print(rules[["antecedents","consequents","support","lift","confidence"]])

