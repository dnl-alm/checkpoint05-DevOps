package br.com.library.dto.request;

import jakarta.validation.constraints.NotBlank;

public record AutorRequest(
        @NotBlank
        String nome,
        String nacionalidade
) {
}
