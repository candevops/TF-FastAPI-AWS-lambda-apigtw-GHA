import json
from fastapi import FastAPI, HTTPException
from starlette.responses import Response

from app.db.models import UserAnswer
from app.api import api
from mangum import Mangum


app = FastAPI()


@app.get("/")
def root():
    # return {"message": "Fast API in Python",}
    message = {
   'message': 'Fast API in Python!'
}
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps(message)
}

@app.get("/user")
def read_user():
    return api.read_user()


@app.get("/question/{position}", status_code=200)
def read_questions(position: int, response: Response):
    question = api.read_questions(position)

    if not question:
        raise HTTPException(status_code=400, detail="Error")

    return question


@app.get("/alternatives/{question_id}")
def read_alternatives(question_id: int):
    return api.read_alternatives(question_id)


@app.post("/answer", status_code=201)
def create_answer(payload: UserAnswer):
    payload = payload.dict()

    return api.create_answer(payload)


@app.get("/result/{user_id}")
def read_result(user_id: int):
    return api.read_result(user_id)

handler = Mangum(app)
