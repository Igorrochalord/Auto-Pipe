import os
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    # Pega a variável de ambiente que definimos no Terraform
    ambiente = os.environ.get("AMBIENTE", "Desenvolvimento")
    return f"<h1>Ola! App rodando no ambiente novo com auto: {ambiente}</h1>"

if __name__ == "__main__":
    # O Cloud Run espera que a app rode na porta definida pela var PORT (padrao 8080)
    port = int(os.environ.get("PORT", 8080))
    app.run(debug=True, host="0.0.0.0", port=port)