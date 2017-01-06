module Cimpress_mcp
    SERVICES = {
        :print_fulfillment_api => {
            :client_id => '4GtkxJhz0U1bdggHMdaySAy05IV4MEDV',
            :health_check_url => 'https://api.cimpress.io/v1/livecheck',
            :endpoint_url => 'https://api.cimpress.io/vcs/printapi/'
        },
        :barcode_image_creator => {
            :client_id => 'lsbRM318dQg5W6yUBW9m8K0hPM9Qg1Uw',
            :health_check_url => 'https://barcode.at.cimpress.io/v1/healthcheck',
            :endpoint_url => 'https://barcode.at.cimpress.io/v1/'
        },
        :rasterization => {
            :client_id => '3Y3QAMHT1CQYaCTtuyhymxfBcznVoZN9',
            :health_check_url => 'https://rasterization.prepress.documents.cimpress.io/status/healthcheck',
            :endpoint_url => 'https://rasterization.prepress.documents.cimpress.io/rasterize/v1/'
        },
        :uploads => {
            :client_id => 'WuPUpCSkomz4mtPxCIXbLdYhgOLf4fhJ',
            :health_check_url => '',
            :endpoint_url => 'https://uploads.documents.cimpress.io/v1/uploads/'
        },
        :document_orchestration => {
            :client_id => 'KXae6kIBE9DcSqHRyQB92PytnbdgykQL',
            :health_check_url => '',
            :endpoint_url => 'https://orchestration.documents.cimpress.io/v1/',
        },
        :fulfillment_recommendations => {
            :client_id => '0o9e54NwpXutAxVkylQXzhoRZN47NEGy',
            :health_check_url => '',
            :endpoint_url => 'https://recommendations.commerce.cimpress.io/v3/'
        },
        :doc_review_clean_image => {
            :client_id => 'M1WTlwEiOHZ0xFIrmztdtlUM47qvqpBC',
         :health_check_url => 'https://cleanimage.docreview.documents.cimpress.io/status/healthcheck',
        :endpoint_url => 'https://cleanimage.docreview.documents.cimpress.io/v1/'
        },
        :crispify => {
            :client_id => 'pl3q5J4khaLTaS7rkv73I87TrTlV7N4I',
            :health_check_url => 'https://gpu.images.documents.cimpress.io/status/healthcheck',
            :endpoint_url => 'https://gpu.images.documents.cimpress.io/crispify/v2/'
        }

    }
end