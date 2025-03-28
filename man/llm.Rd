% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/llm.R
\name{llm}
\alias{llm}
\title{Query an LLM}
\usage{
llm(
  text,
  query,
  text_col = "text",
  model = llm_model(),
  maxTokens = 1024,
  temperature = 0.5,
  top_p = 0.95,
  seed = sample(1e+06:9999999, 1),
  API_KEY = Sys.getenv("GROQ_API_KEY")
)
}
\arguments{
\item{text}{The text to send to the LLM (vector of strings, or data frame with the text in a column)}

\item{query}{The query to ask of the LLM}

\item{text_col}{The name of the text column if text is a data frame}

\item{model}{the LLM model name (see \code{llm_model_list()})}

\item{maxTokens}{The maximum integer of completion tokens returned per query}

\item{temperature}{Controls randomness in responses. Lower values make responses more deterministic. Recommended range: 0.5-0.7 to prevent repetitions or incoherent outputs; valued between 0 inclusive and 2 exclusive}

\item{top_p}{Nucleus sampling threshold (between 0 and 1); usually alter this or temperature, but not both}

\item{seed}{Set for reproducible responses}

\item{API_KEY}{your API key for the LLM}
}
\value{
a list of results
}
\description{
Ask a large language model (LLM) any question you want about a vector of text or the text from a search_text().
}
\details{
You will need to get your own API key from \url{https://console.groq.com/keys}. To avoid having to type it out, add it to the .Renviron file in the following format (you can use \code{usethis::edit_r_environ()} to access the .Renviron file)

GROQ_API_KEY="key_value_asdf"

See \url{https://console.groq.com/docs} for more information
}
\examples{
\donttest{
  text <- c("hello", "number", "ten", 12)
  query <- "Is this a number? Answer only 'TRUE' or 'FALSE'"
  is_number <- llm(text, query)
  is_number
}
}
