package br.com.library.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record LivroRequest(
        @NotBlank
        String titulo,

        Integer anoPublicacao,

        @NotNull
        Long autorId
) {
}
