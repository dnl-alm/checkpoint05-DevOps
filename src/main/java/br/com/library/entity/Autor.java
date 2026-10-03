package br.com.library.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "t_autor")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Autor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Setter(AccessLevel.NONE)
    private Long id;

    @Column(nullable = false)
    private String nome;

    private String nacionalidade;

    @OneToMany(mappedBy = "autor")
    @Setter(AccessLevel.NONE)
    private List<Livro> livros = new ArrayList<>();

    public Autor(String nome, String nacionalidade) {
        this.nome = nome;
        this.nacionalidade = nacionalidade;
    }
}