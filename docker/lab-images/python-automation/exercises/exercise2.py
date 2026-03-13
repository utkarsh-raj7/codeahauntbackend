"""
Exercise 2: API Client
Task: Use the requests library to:
1. Fetch data from https://jsonplaceholder.typicode.com/posts
2. Filter posts by userId=1
3. Print each post's title
"""
import requests

def get_posts_by_user(user_id):
    # TODO: implement this
    pass

if __name__ == "__main__":
    posts = get_posts_by_user(1)
    print(f"Found {len(posts)} posts")
